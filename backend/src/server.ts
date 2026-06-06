import Fastify from 'fastify'
import healthRoute from './routes/health'

const server = Fastify({
  logger: true
})

// Register routes
server.register(healthRoute)

const start = async () => {
  try {
    await server.listen({ port: 3000, host: '0.0.0.0' })
    console.log('Server running on http://localhost:3000')
  } catch (err) {
    server.log.error(err)
    process.exit(1)
  }
}

start()
